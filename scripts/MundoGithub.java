import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.time.ZoneOffset;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

// Sobe o mundo para o repositorio do mundo no GitHub, de onde a Action da pagina tira o mapa e o placar.
// O iniciar.sh e o iniciar.ps1 rodam depois de enviar o mundo para o Drive, com o Java do servidor:
//   java scripts/MundoGithub.java MUNDO.TAR.GZ PASTA_DO_DRIVE
// github.txt na pasta do Drive: na primeira linha o token (fine-grained, Contents: read and write so no
// repositorio do mundo); numa segunda linha opcional, outro repositorio no lugar de PedroTessaro/minezada-mundo.
// Sem github.txt nao faz nada. Cada envio vira um arquivo mundo-AAAAMMDD-HHMMSS.tar.gz (hora UTC, igual em
// todo host) no release "mundo"; os dois mais novos ficam (a Action pode estar baixando o anterior) e o resto e apagado. O Drive continua sendo
// o mundo que vale: qualquer falha aqui so avisa.
public class MundoGithub {
    static final String REPO = "PedroTessaro/minezada-mundo";
    static final String TAG = "mundo";
    static final int FICAM = 2;
    static final HttpClient HTTP = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(15))
        .followRedirects(HttpClient.Redirect.NEVER).build();
    // MINEZADA_API: so para o teste, que troca o GitHub por um servidor falso.
    static final String API = System.getenv().getOrDefault("MINEZADA_API", "https://api.github.com");
    static String token;

    public static void main(String[] args) throws Exception {
        Path arquivo = Path.of(args[0]), conf = Path.of(args[1]).resolve("github.txt");
        if (!Files.exists(conf)) return;
        List<String> linhas = new ArrayList<>();
        for (String l : Files.readAllLines(conf, StandardCharsets.UTF_8)) {
            l = l.replace("﻿", "").trim();
            if (!l.isEmpty()) linhas.add(l);
        }
        if (linhas.isEmpty()) falha("github.txt vazio.");
        token = linhas.get(0);
        String repo = linhas.size() > 1 ? linhas.get(1) : REPO;
        if (!repo.matches("[\\w.-]+/[\\w.-]+")) falha("repositorio invalido em github.txt: " + repo);

        System.out.println("Enviando o mundo para o GitHub (" + repo + "), para o mapa e o placar da pagina...");
        Map<String, Object> rel = release(repo);
        String nome = "mundo-" + ZonedDateTime.now(ZoneOffset.UTC).format(DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss")) + ".tar.gz";
        String upload = ((String) rel.get("upload_url")).replaceAll("\\{.*\\}$", "")
            + "?name=" + URLEncoder.encode(nome, StandardCharsets.UTF_8);
        HttpResponse<String> r = HTTP.send(pedido(upload).timeout(Duration.ofMinutes(15))
            .header("Content-Type", "application/gzip")
            .POST(HttpRequest.BodyPublishers.ofFile(arquivo)).build(), HttpResponse.BodyHandlers.ofString());
        if (r.statusCode() != 201) falha("o GitHub recusou o arquivo (HTTP " + r.statusCode() + "): " + curto(r.body()));

        // Os mais novos primeiro: o nome tem a data.
        List<Map<String, Object>> velhos = new ArrayList<>();
        for (Object o : (List<?>) json(get(API + "/repos/" + repo + "/releases/" + num(rel.get("id")) + "/assets?per_page=100", 200).body())) {
            @SuppressWarnings("unchecked") Map<String, Object> a = (Map<String, Object>) o;
            if (((String) a.get("name")).matches("mundo-\\d{8}-\\d{6}\\.tar\\.gz")) velhos.add(a);
        }
        velhos.sort((a, b) -> ((String) b.get("name")).compareTo((String) a.get("name")));
        for (Map<String, Object> a : velhos.subList(Math.min(FICAM, velhos.size()), velhos.size())) {
            HttpResponse<String> d = HTTP.send(pedido(API + "/repos/" + repo + "/releases/assets/" + num(a.get("id"))).DELETE().build(),
                HttpResponse.BodyHandlers.ofString());
            if (d.statusCode() != 204) System.out.println("AVISO: nao consegui apagar " + a.get("name") + " (HTTP " + d.statusCode() + ").");
        }
        System.out.println("Mundo no GitHub: " + nome + ". A pagina atualiza em ate meia hora.");
    }

    // O release "mundo"; na primeira vez, cria (o repositorio precisa de um commit, por exemplo um README).
    static Map<String, Object> release(String repo) throws Exception {
        HttpResponse<String> r = get(API + "/repos/" + repo + "/releases/tags/" + TAG, -1);
        if (r.statusCode() == 404) {
            String corpo = "{\"tag_name\":\"" + TAG + "\",\"name\":\"Mundo\",\"body\":\"O mundo da Minezada, enviado pelo iniciar a cada stop.\"}";
            r = HTTP.send(pedido(API + "/repos/" + repo + "/releases").header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(corpo)).build(), HttpResponse.BodyHandlers.ofString());
            if (r.statusCode() == 404) falha("repositorio " + repo + " nao encontrado, ou o token nao tem acesso a ele.");
            if (r.statusCode() == 422) falha("o repositorio " + repo + " esta vazio: crie ele com um README.");
            if (r.statusCode() != 201) falha("nao consegui criar o release (HTTP " + r.statusCode() + "): " + curto(r.body()));
        } else if (r.statusCode() != 200) {
            falha(r.statusCode() == 401 ? "o token de github.txt nao vale mais (expirou ou foi apagado)."
                : "o GitHub respondeu HTTP " + r.statusCode() + ": " + curto(r.body()));
        }
        @SuppressWarnings("unchecked") Map<String, Object> m = (Map<String, Object>) json(r.body());
        return m;
    }

    static HttpRequest.Builder pedido(String url) {
        return HttpRequest.newBuilder(URI.create(url)).timeout(Duration.ofSeconds(30))
            .header("Authorization", "Bearer " + token)
            .header("Accept", "application/vnd.github+json")
            .header("X-GitHub-Api-Version", "2022-11-28");
    }

    static HttpResponse<String> get(String url, int espera) throws Exception {
        HttpResponse<String> r = HTTP.send(pedido(url).GET().build(), HttpResponse.BodyHandlers.ofString());
        if (espera > 0 && r.statusCode() != espera) falha("o GitHub respondeu HTTP " + r.statusCode() + ": " + curto(r.body()));
        return r;
    }

    static String num(Object o) { return String.valueOf(((Number) o).longValue()); }
    static String curto(String s) { return s.length() > 200 ? s.substring(0, 200) + "..." : s; }

    static void falha(String msg) {
        System.out.println("AVISO: mundo nao enviado para o GitHub: " + msg + " (o do Drive esta salvo; o mapa da pagina so fica atrasado)");
        System.exit(1);
    }

    // JSON da API: objetos viram Map, listas List, numeros Double. So o necessario para ler o que o GitHub manda.
    static int at;
    static Object json(String s) { at = 0; Object v = valor(s); return v; }

    static Object valor(String s) {
        espaco(s);
        char c = s.charAt(at);
        if (c == '{') {
            Map<String, Object> m = new LinkedHashMap<>();
            at++;
            espaco(s);
            if (s.charAt(at) == '}') { at++; return m; }
            while (true) {
                espaco(s);
                String k = texto(s);
                espaco(s);
                at++; // ':'
                m.put(k, valor(s));
                espaco(s);
                if (s.charAt(at++) == '}') return m;
            }
        }
        if (c == '[') {
            List<Object> l = new ArrayList<>();
            at++;
            espaco(s);
            if (s.charAt(at) == ']') { at++; return l; }
            while (true) {
                l.add(valor(s));
                espaco(s);
                if (s.charAt(at++) == ']') return l;
            }
        }
        if (c == '"') return texto(s);
        if (s.startsWith("true", at)) { at += 4; return true; }
        if (s.startsWith("false", at)) { at += 5; return false; }
        if (s.startsWith("null", at)) { at += 4; return null; }
        int ini = at;
        while (at < s.length() && "+-0123456789.eE".indexOf(s.charAt(at)) >= 0) at++;
        return Double.parseDouble(s.substring(ini, at));
    }

    static String texto(String s) {
        StringBuilder b = new StringBuilder();
        at++; // '"'
        while (true) {
            char c = s.charAt(at++);
            if (c == '"') return b.toString();
            if (c != '\\') { b.append(c); continue; }
            char e = s.charAt(at++);
            switch (e) {
                case 'n' -> b.append('\n');
                case 't' -> b.append('\t');
                case 'r' -> b.append('\r');
                case 'b' -> b.append('\b');
                case 'f' -> b.append('\f');
                case 'u' -> { b.append((char) Integer.parseInt(s.substring(at, at + 4), 16)); at += 4; }
                default -> b.append(e);
            }
        }
    }

    static void espaco(String s) { while (at < s.length() && Character.isWhitespace(s.charAt(at))) at++; }
}
