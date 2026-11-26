import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;

// Servidor falso para scripts/testes/desligar.sh: trata os sinais como o servidor de verdade (a JVM salva o mundo no
// gancho de desligamento com SIGTERM/SIGHUP, ignora SIGINT herdado ignorado, e o console fechado nao desliga nada).
public class Servidor {
    static boolean salvo;

    public static void main(String[] args) throws Exception {
        Runtime.getRuntime().addShutdownHook(new Thread(() -> salvar("sinal")));
        Files.writeString(Path.of("pid"), Long.toString(ProcessHandle.current().pid()));
        System.out.println("Done (0.1s)! For help, type \"help\"");
        log("Done (0.1s)!");
        Files.writeString(Path.of("rodando"), "");
        BufferedReader console = new BufferedReader(new InputStreamReader(System.in));
        String linha;
        while ((linha = console.readLine()) != null) {
            Files.writeString(Path.of("console.txt"), linha + "\n", java.nio.file.StandardOpenOption.CREATE, java.nio.file.StandardOpenOption.APPEND);
            // Foto do mundo (iniciar.sh): confirma o save-all com atraso, como um mundo grande.
            if (linha.trim().startsWith("save-all")) {
                Thread.sleep(1500);
                log("Saved the game");
            }
            if (linha.trim().equals("stop")) {
                salvar("stop");
                System.exit(0);
            }
        }
        // Console fechado (janela fechada): o servidor de verdade segue rodando ate receber um sinal.
        Thread.sleep(Long.MAX_VALUE);
    }

    static void log(String linha) throws Exception {
        Files.createDirectories(Path.of("logs"));
        Files.writeString(Path.of("logs/latest.log"), linha + "\n", java.nio.file.StandardOpenOption.CREATE, java.nio.file.StandardOpenOption.APPEND);
    }

    static synchronized void salvar(String como) {
        if (salvo) return;
        salvo = true;
        System.out.println("Saving worlds (" + como + ")");
        try {
            Thread.sleep(500);
            Files.writeString(Path.of("salvo"), como);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
