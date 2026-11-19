import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

// Testa o scripts/Whitelist.java com o caso de scripts/testes/whitelist/ (sem consultas a Mojang).
// Uso, da raiz do repo: java scripts/testes/WhitelistTeste.java
public class WhitelistTeste {
    public static void main(String[] args) throws Exception {
        Path caso = Path.of("scripts/testes/whitelist"), t = Files.createTempDirectory("minezada-teste");
        try (Stream<Path> s = Files.walk(caso)) {
            for (Path p : s.toList()) Files.copy(p, t.resolve(caso.relativize(p).toString()), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
        }
        String java = Path.of(System.getProperty("java.home"), "bin", "java").toString();
        int saida = new ProcessBuilder(java, "scripts/Whitelist.java", t.resolve("jogadores.txt").toString(), t.toString()).inheritIO().start().waitFor();
        String esperado = Files.readString(t.resolve("esperado.json"));
        List<String> erros = new ArrayList<>();
        if (saida != 0) erros.add("Whitelist.java saiu com " + saida);
        for (String nome : List.of("whitelist", "ops")) {
            Matcher m = Pattern.compile("\"" + nome + "\"\\s*:\\s*\\[(.*?)\\]", Pattern.DOTALL).matcher(esperado);
            m.find();
            List<String> quer = chaves(m.group(1)), veio = chaves(Files.readString(t.resolve(nome + ".json")));
            if (!quer.equals(veio)) erros.add(nome + ".json: esperado " + quer + ", veio " + veio);
        }
        Matcher c = Pattern.compile("\"copiados\"\\s*:\\s*\\[(.*?)\\]", Pattern.DOTALL).matcher(esperado);
        c.find();
        Matcher a = Pattern.compile("\"([^\"]+)\"").matcher(c.group(1));
        while (a.find()) if (!Files.exists(t.resolve(a.group(1)))) erros.add("progresso nao copiado: " + a.group(1));
        if (!erros.isEmpty()) {
            System.out.println("FALHA whitelist:\n  " + String.join("\n  ", erros));
            System.exit(1);
        }
        System.out.println("ok    whitelist");
    }

    // Cada entrada vira "uuid|nome[|nivel]", em ordem, para comparar sem depender da ordem do arquivo.
    static List<String> chaves(String json) {
        List<String> l = new ArrayList<>();
        Matcher o = Pattern.compile("\\{[^{}]*\\}").matcher(json);
        while (o.find()) {
            String e = o.group();
            String k = campo(e, "uuid") + "|" + campo(e, "name");
            String nivel = campo(e, "level");
            l.add(nivel.isEmpty() ? k : k + "|" + nivel);
        }
        l.sort(null);
        return l;
    }

    static String campo(String obj, String nome) {
        Matcher m = Pattern.compile("\"" + nome + "\"\\s*:\\s*\"?([^\",}]*)").matcher(obj);
        return m.find() ? m.group(1).trim() : "";
    }
}
