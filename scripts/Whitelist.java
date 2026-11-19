import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

// Libera na whitelist os nicks de jogadores.txt (um por linha; "op" depois do nick tambem da admin).
// MixAuth: quem tem original entra com o UUID oficial (so ele e liberado); sem original, com o offline.
// Sem o arquivo, cria com o dono e quem ja esta liberado. So adiciona; tirar alguem e no console.
// --do-jogo LISTA PASTA: o caminho contrario, para /whitelist add e /op feitos no jogo (ver doJogo).
// O iniciar.ps1 e o iniciar.sh rodam com o Java do servidor: java scripts/Whitelist.java LISTA PASTA_DO_SERVIDOR
public class Whitelist {
    static final Pattern OBJETO = Pattern.compile("\\{[^{}]*\\}");
    static final Pattern CAMPO = Pattern.compile("\"(\\w+)\"\\s*:\\s*(\"[^\"]*\"|true|false|-?\\d+)");
    static final String FALHA = "FALHA";  // a Mojang nao respondeu: nao mexe nas entradas deste nick neste start
    static final HttpClient HTTP = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
    static final Map<String, String> oficiais = new HashMap<>();

    public static void main(String[] args) throws Exception {
        if (args[0].equals("--do-jogo")) {
            doJogo(Path.of(args[1]), Path.of(args[2]));
            return;
        }
        Path lista = Path.of(args[0]), pasta = Path.of(args[1]), mundo = pasta.resolve("world");
        List<Map<String, String>> wl = ler(pasta.resolve("whitelist.json")), ops = ler(pasta.resolve("ops.json"));
        // UUID oficial ja conhecido (whitelist/ops) evita consultar a Mojang a cada start.
        for (List<Map<String, String>> l : List.of(wl, ops)) {
            for (Map<String, String> e : l) {
                if (!uuid(e).equals(offline(nome(e)))) oficiais.put(nome(e).toLowerCase(), uuid(e));
            }
        }
        if (!Files.exists(lista)) {
            StringBuilder s = new StringBuilder("# Um nick por linha, igual ao do jogo (maiusculas contam); 'op' depois tambem da admin.\n"
                + "# 'sem-original' depois: joga sem Minecraft original com um nick que existe como conta original.\n"
                + "# O servidor confere este arquivo a cada 30 segundos. No jogo, quem e op pode usar /whitelist add e /op: o nick vem para ca.\nEnzobullet op\n");
            for (Map<String, String> e : wl) {
                if (!nome(e).equalsIgnoreCase("Enzobullet")) s.append(nome(e)).append('\n');
            }
            Files.writeString(lista, s);
        }
        for (String linha : Files.readAllLines(lista, StandardCharsets.UTF_8)) {
            String[] partes = linha.replace("﻿", "").split("#", 2)[0].trim().split("\\s+");
            if (partes[0].isEmpty()) continue;
            String nome = partes[0];
            if (!nome.matches("[A-Za-z0-9_]{1,16}")) {
                System.out.println("AVISO: nick invalido em jogadores.txt: " + nome);
                continue;
            }
            List<String> flags = new ArrayList<>();
            for (int i = 1; i < partes.length; i++) flags.add(partes[i].toLowerCase());
            String off = offline(nome);
            String on = flags.contains("sem-original") ? null : oficial(nome);
            if (FALHA.equals(on)) continue;
            if (on != null) {
                // Nick com original: so o UUID oficial. O offline liberado deixaria qualquer um sem original
                // entrar com esse nick (o MixAuth so pede senha) e herdar op e progresso.
                if (wl.removeIf(e -> uuid(e).equals(off))) System.out.println("UUID offline de " + nome + " tirado da whitelist (ele tem original).");
                if (ops.removeIf(e -> uuid(e).equals(off))) System.out.println("UUID offline de " + nome + " tirado dos ops (ele tem original).");
                // Progresso de antes (UUID offline) copiado para o oficial, so se o oficial ainda nao tem nada.
                for (String a : List.of("playerdata/%s.dat", "advancements/%s.json", "stats/%s.json")) {
                    Path de = mundo.resolve(a.formatted(off)), para = mundo.resolve(a.formatted(on));
                    if (Files.exists(de) && !Files.exists(para)) {
                        Files.copy(de, para);
                        System.out.println("Progresso de " + nome + " copiado para o UUID oficial: " + a.formatted(on));
                    }
                }
            }
            String u = on != null ? on : off;
            if (wl.stream().noneMatch(e -> uuid(e).equals(u))) {
                wl.add(entrada(u, nome, false));
                System.out.println("Liberado na whitelist: " + nome + (on != null ? " (original)" : " (sem original)"));
            }
            if (flags.contains("op") && ops.stream().noneMatch(e -> uuid(e).equals(u))) {
                ops.add(entrada(u, nome, true));
                System.out.println("Admin (op): " + nome);
            }
        }
        escrever(pasta.resolve("whitelist.json"), wl);
        escrever(pasta.resolve("ops.json"), ops);
    }

    // /whitelist add e /op no jogo: copia para o jogadores.txt quem esta no whitelist.json ou no ops.json e falta na
    // lista. O iniciar roda isto quando o servidor muda esses arquivos; a lista nova passa depois pela conferencia
    // normal, que troca o UUID offline pelo oficial de quem tem original. Tirar alguem continua sendo no jogo e na lista.
    static void doJogo(Path lista, Path pasta) throws Exception {
        if (!Files.exists(lista)) return;
        List<String> linhas = new ArrayList<>(Files.readAllLines(lista, StandardCharsets.UTF_8));
        Map<String, Integer> linhaDe = new HashMap<>();
        for (int i = 0; i < linhas.size(); i++) {
            String nick = linhas.get(i).replace("﻿", "").split("#", 2)[0].trim().split("\\s+")[0];
            if (!nick.isEmpty()) linhaDe.put(nick.toLowerCase(), i);
        }
        List<String> ops = new ArrayList<>();
        for (Map<String, String> e : ler(pasta.resolve("ops.json"))) ops.add(nome(e).toLowerCase());
        List<Map<String, String>> todos = ler(pasta.resolve("whitelist.json"));
        todos.addAll(ler(pasta.resolve("ops.json")));
        boolean mudou = false;
        for (Map<String, String> e : todos) {
            String nick = nome(e);
            if (!nick.matches("[A-Za-z0-9_]{1,16}")) continue;
            boolean op = ops.contains(nick.toLowerCase());
            Integer i = linhaDe.get(nick.toLowerCase());
            if (i == null) {
                linhas.add(nick + (op ? " op" : ""));
                linhaDe.put(nick.toLowerCase(), linhas.size() - 1);
                System.out.println("Liberado pelo jogo, copiado para o jogadores.txt: " + nick + (op ? " (op)" : ""));
                mudou = true;
            } else if (op) {
                String l = linhas.get(i);
                int h = l.indexOf('#');
                String codigo = h < 0 ? l : l.substring(0, h);
                if (List.of(codigo.trim().toLowerCase().split("\\s+")).contains("op")) continue;
                linhas.set(i, codigo.stripTrailing() + " op" + (h < 0 ? "" : " " + l.substring(h)));
                System.out.println("Admin pelo jogo, marcado no jogadores.txt: " + nick);
                mudou = true;
            }
        }
        if (mudou) Files.write(lista, linhas, StandardCharsets.UTF_8);
    }

    // Mesmo UUID que o servidor da ao nick sem conta Microsoft (maiusculas contam).
    static String offline(String nome) {
        return UUID.nameUUIDFromBytes(("OfflinePlayer:" + nome).getBytes(StandardCharsets.UTF_8)).toString();
    }

    // UUID oficial, null (nick sem original) ou FALHA.
    static String oficial(String nome) {
        if (oficiais.containsKey(nome.toLowerCase())) return oficiais.get(nome.toLowerCase());
        // Dois enderecos da Mojang: rede compartilhada (faculdade) costuma levar 429 em um deles.
        for (String url : List.of("https://api.mojang.com/users/profiles/minecraft/", "https://api.minecraftservices.com/minecraft/profile/lookup/name/")) {
            try {
                HttpResponse<String> r = HTTP.send(HttpRequest.newBuilder(URI.create(url + nome)).timeout(Duration.ofSeconds(5)).build(), HttpResponse.BodyHandlers.ofString());
                if (r.statusCode() == 404) return null;  // nick sem conta original
                Matcher m = Pattern.compile("\"id\"\\s*:\\s*\"([0-9a-f]{32})\"").matcher(r.body());
                if (r.statusCode() == 200 && m.find()) return m.group(1).replaceFirst("(.{8})(.{4})(.{4})(.{4})(.{12})", "$1-$2-$3-$4-$5");
            } catch (Exception e) {
                // tenta o outro endereco
            }
        }
        System.out.println("AVISO: a Mojang nao respondeu sobre " + nome + "; whitelist dele fica como estava ate o proximo start.");
        return FALHA;
    }

    // whitelist.json e ops.json do servidor: lista de objetos sem aninhamento. Guarda cada valor como esta no JSON.
    static List<Map<String, String>> ler(Path arq) throws Exception {
        List<Map<String, String>> l = new ArrayList<>();
        if (!Files.exists(arq)) return l;
        Matcher o = OBJETO.matcher(Files.readString(arq));
        while (o.find()) {
            Map<String, String> e = new LinkedHashMap<>();
            Matcher c = CAMPO.matcher(o.group());
            while (c.find()) e.put(c.group(1), c.group(2));
            l.add(e);
        }
        return l;
    }

    static Map<String, String> entrada(String uuid, String nome, boolean op) {
        Map<String, String> e = new LinkedHashMap<>();
        e.put("uuid", '"' + uuid + '"');
        e.put("name", '"' + nome + '"');
        if (op) {
            e.put("level", "4");
            e.put("bypassesPlayerLimit", "false");
        }
        return e;
    }

    static String uuid(Map<String, String> e) { return e.getOrDefault("uuid", "\"\"").replace("\"", ""); }

    static String nome(Map<String, String> e) { return e.getOrDefault("name", "\"\"").replace("\"", ""); }

    static void escrever(Path arq, List<Map<String, String>> l) throws Exception {
        List<String> objs = new ArrayList<>();
        for (Map<String, String> e : l) {
            List<String> campos = new ArrayList<>();
            e.forEach((k, v) -> campos.add('"' + k + "\": " + v));
            objs.add("  {" + String.join(", ", campos) + "}");
        }
        Files.writeString(arq, l.isEmpty() ? "[]\n" : "[\n" + String.join(",\n", objs) + "\n]\n");
    }
}
