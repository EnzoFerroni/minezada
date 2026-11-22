import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

// Testa o scripts/MundoGithub.java contra um GitHub falso, local (sem rede).
// Uso, da raiz do repo: java scripts/testes/MundoGithubTeste.java
public class MundoGithubTeste {
    static boolean temRelease;
    static boolean tokenVale = true;
    static final Map<Integer, String> assets = new TreeMap<>();
    static final List<String> erros = new ArrayList<>();
    static final List<Integer> apagados = new ArrayList<>();
    static byte[] recebido;
    static int pedidos, paginas;
    static String base;

    public static void main(String[] args) throws Exception {
        HttpServer srv = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        srv.createContext("/", MundoGithubTeste::responde);
        srv.start();
        base = "http://127.0.0.1:" + srv.getAddress().getPort();

        Path drive = Files.createTempDirectory("minezada-drive");
        Path mundo = drive.resolve("mundo.tar.gz");
        byte[] conteudo = new byte[300_000];
        for (int i = 0; i < conteudo.length; i++) conteudo[i] = (byte) (i * 31);
        Files.write(mundo, conteudo);

        // Sem github.txt: nao faz nada e nao chama o GitHub.
        int s = roda(mundo, drive);
        if (s != 0 || pedidos != 0) erros.add("sem github.txt: saiu com " + s + " e fez " + pedidos + " pedidos");

        // Primeira vez: cria o release, sobe o arquivo e apaga os antigos, deixando os dois mais novos.
        Files.writeString(drive.resolve("github.txt"), "﻿token-de-teste\nalguem/mundo-teste\n");
        assets.put(1, "mundo-20260101-100000.tar.gz");
        assets.put(2, "mundo-20260301-100000.tar.gz");
        assets.put(3, "outra-coisa.zip");
        assets.put(4, "mundo-20260201-100000.tar.gz");
        s = roda(mundo, drive);
        if (s != 0) erros.add("envio: saiu com " + s);
        if (!temRelease) erros.add("envio: o release nao foi criado");
        if (recebido == null || !Arrays.equals(recebido, conteudo)) erros.add("envio: o arquivo chegou diferente");
        if (!apagados.equals(List.of(4, 1))) erros.add("envio: apagou " + apagados + ", esperado [4, 1]");
        if (!assets.containsKey(2) || !assets.containsKey(3) || assets.size() != 3) erros.add("envio: ficaram " + assets.values());

        // Sem dispatch.txt a pagina nao e avisada; com ele, o envio pede a Action pagina.yml do repositorio dele.
        if (paginas != 0) erros.add("aviso da pagina sem dispatch.txt");
        Files.writeString(drive.resolve("dispatch.txt"), "token-de-teste\nalguem/pack-teste\n");
        s = roda(mundo, drive);
        if (s != 0 || paginas != 1) erros.add("aviso da pagina: saiu com " + s + " e avisou " + paginas + " vez(es)");

        // Token que nao vale mais: avisa e sai com 1.
        tokenVale = false;
        s = roda(mundo, drive);
        if (s != 1) erros.add("token vencido: saiu com " + s + ", esperado 1");

        srv.stop(0);
        if (!erros.isEmpty()) {
            System.out.println("FALHA mundo no GitHub:\n  " + String.join("\n  ", erros));
            System.exit(1);
        }
        System.out.println("ok    mundo no GitHub");
    }

    static int roda(Path mundo, Path drive) throws Exception {
        String java = Path.of(System.getProperty("java.home"), "bin", "java").toString();
        ProcessBuilder pb = new ProcessBuilder(java, "scripts/MundoGithub.java", mundo.toString(), drive.toString()).inheritIO();
        pb.environment().put("MINEZADA_API", base);
        return pb.start().waitFor();
    }

    static void responde(HttpExchange x) throws java.io.IOException {
        pedidos++;
        String m = x.getRequestMethod(), p = x.getRequestURI().getPath(), q = x.getRequestURI().getQuery();
        byte[] corpo = x.getRequestBody().readAllBytes();
        if (!"Bearer token-de-teste".equals(x.getRequestHeaders().getFirst("Authorization"))) erros.add(m + " " + p + " sem o token");
        if (!tokenVale) { manda(x, 401, "{\"message\":\"Bad credentials\"}"); return; }
        String rel = "{\"id\": 77, \"upload_url\": \"" + base + "/upload/77/assets{?name,label}\", \"author\": {\"id\": 5}}";
        if (m.equals("GET") && p.equals("/repos/alguem/mundo-teste/releases/tags/mundo")) {
            manda(x, temRelease ? 200 : 404, temRelease ? rel : "{\"message\":\"Not Found\"}");
        } else if (m.equals("POST") && p.equals("/repos/alguem/mundo-teste/releases")) {
            if (!new String(corpo, StandardCharsets.UTF_8).contains("\"tag_name\":\"mundo\"")) erros.add("release criado sem a tag mundo");
            temRelease = true;
            manda(x, 201, rel);
        } else if (m.equals("POST") && p.equals("/upload/77/assets")) {
            recebido = corpo;
            String nome = q.substring("name=".length());
            if (!nome.matches("mundo-\\d{8}-\\d{6}\\.tar\\.gz")) erros.add("nome do arquivo: " + nome);
            assets.put(9, nome);
            manda(x, 201, "{\"id\": 9}");
        } else if (m.equals("POST") && p.equals("/repos/alguem/pack-teste/actions/workflows/pagina.yml/dispatches")) {
            paginas++;
            x.sendResponseHeaders(204, -1);
            x.close();
        } else if (m.equals("GET") && p.equals("/repos/alguem/mundo-teste/releases/77/assets")) {
            StringBuilder b = new StringBuilder("[");
            for (var e : assets.entrySet()) {
                if (b.length() > 1) b.append(',');
                b.append("{\"id\": ").append(e.getKey()).append(", \"name\": \"").append(e.getValue())
                    .append("\", \"uploader\": {\"login\": \"x\", \"id\": 1}}");
            }
            manda(x, 200, b.append(']').toString());
        } else if (m.equals("DELETE") && p.startsWith("/repos/alguem/mundo-teste/releases/assets/")) {
            int id = Integer.parseInt(p.substring(p.lastIndexOf('/') + 1));
            apagados.add(id);
            assets.remove(id);
            x.sendResponseHeaders(204, -1);
            x.close();
        } else {
            erros.add("pedido inesperado: " + m + " " + p);
            manda(x, 500, "{}");
        }
    }

    static void manda(HttpExchange x, int code, String s) throws java.io.IOException {
        byte[] b = s.getBytes(StandardCharsets.UTF_8);
        x.sendResponseHeaders(code, b.length);
        x.getResponseBody().write(b);
        x.close();
    }
}
