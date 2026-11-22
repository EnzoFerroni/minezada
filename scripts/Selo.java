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

// Pede ao GitHub a consulta do selo agora, sem esperar o horario: o agendamento de 10 em 10 minutos o GitHub roda
// quando quer (ja passou horas sem rodar), e um pedido feito assim ele atende em segundos.
// O iniciar.sh e o iniciar.ps1 chamam ao ligar o servidor, a cada 10 minutos com ele ligado e depois do stop:
//   java scripts/Selo.java PASTA_DO_DRIVE ligou|ligado|desligou
// dispatch.txt na pasta do Drive: na primeira linha o token (fine-grained, so Actions: read and write no
// repositorio do pack; ele pede rodadas, nao mexe em arquivo); numa segunda linha opcional, outro repositorio no
// lugar de EnzoFerroni/minezada. Sem dispatch.txt nao faz nada. Falha so avisa: o horario do GitHub continua.
public class Selo {
    static final String REPO = "EnzoFerroni/minezada";
    // MINEZADA_API: so para o teste, que troca o GitHub por um servidor falso.
    static final String API = System.getenv().getOrDefault("MINEZADA_API", "https://api.github.com");

    public static void main(String[] args) throws Exception {
        Path conf = Path.of(args[0]).resolve("dispatch.txt");
        String motivo = args[1];
        if (!motivo.matches("ligou|ligado|desligou")) {
            System.out.println("AVISO: motivo do selo desconhecido: " + motivo);
            System.exit(2);
        }
        if (!Files.exists(conf)) return;
        List<String> linhas = new ArrayList<>();
        for (String l : Files.readAllLines(conf, StandardCharsets.UTF_8)) {
            l = l.replace("﻿", "").trim();
            if (!l.isEmpty()) linhas.add(l);
        }
        if (linhas.isEmpty()) falha("dispatch.txt vazio.");
        String repo = linhas.size() > 1 ? linhas.get(1) : REPO;
        if (!repo.matches("[\\w.-]+/[\\w.-]+")) falha("repositorio invalido em dispatch.txt: " + repo);
        HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).build();
        HttpRequest pedido = HttpRequest.newBuilder(URI.create(API + "/repos/" + repo + "/actions/workflows/status.yml/dispatches"))
            .timeout(Duration.ofSeconds(20))
            .header("Authorization", "Bearer " + linhas.get(0))
            .header("Accept", "application/vnd.github+json")
            .header("X-GitHub-Api-Version", "2022-11-28")
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString("{\"ref\":\"main\",\"inputs\":{\"motivo\":\"" + motivo + "\"}}"))
            .build();
        HttpResponse<String> r;
        try {
            r = http.send(pedido, HttpResponse.BodyHandlers.ofString());
        } catch (java.io.IOException e) {
            falha("sem conexao com o GitHub (" + e.getMessage() + ").");
            return;
        }
        if (r.statusCode() == 401) falha("o token de dispatch.txt nao vale mais (expirou ou foi apagado).");
        if (r.statusCode() == 403 || r.statusCode() == 404) falha("o token de dispatch.txt nao pode rodar Actions em " + repo + " (HTTP " + r.statusCode() + ").");
        if (r.statusCode() != 204) falha("o GitHub respondeu HTTP " + r.statusCode() + ".");
        if (!motivo.equals("ligado")) System.out.println("Selo avisado: " + motivo + " (muda em poucos minutos).");
    }

    static void falha(String msg) {
        System.out.println("AVISO: selo nao avisado: " + msg + " (ele se atualiza sozinho mais tarde)");
        System.exit(1);
    }
}
