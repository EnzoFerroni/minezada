import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;

// Pede ao GitHub para rodar uma Action agora (workflow_dispatch), em vez de esperar o cron, que o GitHub atrasa por horas:
//   java scripts/Avisar.java PASTA_DO_DRIVE status.yml|pagina.yml
// dispatch.txt na pasta do Drive: na primeira linha um token fine-grained so com "Actions: read and write" no repositorio
// da Minezada; numa segunda linha opcional, outro repositorio no lugar de EnzoFerroni/minezada. Sem dispatch.txt nao faz
// nada. Qualquer falha so avisa: o cron continua como reserva.
public class Avisar {
    public static void main(String[] args) throws Exception {
        Path conf = Path.of(args[0]).resolve("dispatch.txt");
        String fluxo = args[1];
        if (!Files.exists(conf)) return;
        List<String> linhas = new ArrayList<>();
        for (String l : Files.readAllLines(conf, StandardCharsets.UTF_8)) {
            l = l.replace("﻿", "").trim();
            if (!l.isEmpty()) linhas.add(l);
        }
        if (linhas.isEmpty()) { System.out.println("AVISO: dispatch.txt vazio."); return; }
        String repo = linhas.size() > 1 ? linhas.get(1) : "EnzoFerroni/minezada";
        if (!repo.matches("[\\w.-]+/[\\w.-]+") || !fluxo.matches("[\\w.-]+\\.yml")) { System.out.println("AVISO: repositorio ou Action invalido."); return; }
        String api = System.getenv().getOrDefault("MINEZADA_API", "https://api.github.com");
        try {
            HttpResponse<String> r = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).build().send(
                HttpRequest.newBuilder(URI.create(api + "/repos/" + repo + "/actions/workflows/" + fluxo + "/dispatches"))
                    .timeout(Duration.ofSeconds(20))
                    .header("Authorization", "Bearer " + linhas.get(0))
                    .header("Accept", "application/vnd.github+json")
                    .header("X-GitHub-Api-Version", "2022-11-28")
                    .POST(HttpRequest.BodyPublishers.ofString("{\"ref\":\"main\"}")).build(),
                HttpResponse.BodyHandlers.ofString());
            if (r.statusCode() != 204) System.out.println("AVISO: o GitHub recusou o aviso para " + fluxo + " (HTTP " + r.statusCode() + ").");
        } catch (Exception e) {
            System.out.println("AVISO: nao consegui avisar o GitHub (" + e.getClass().getSimpleName() + ").");
        }
    }
}
