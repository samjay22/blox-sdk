import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import sam.tech.fields.FieldsException;
import sam.tech.fields.JsonSupport;
import sam.tech.fields.TypeSystem;
import sam.tech.fields.Models;
import sam.tech.fields.integrations.IntegrationBindings;

/** Pure source-level oracle: no Spring context, backend startup, sockets or database. */
public final class FieldsVectors {
    private FieldsVectors() { }
    /** Evaluate shared vectors against the actual server TypeSystem compiled alongside this harness. */
    public static void main(String[] args) throws Exception {
        JsonNode cases = JsonSupport.JSON.readTree(Files.readString(Path.of(args[0])));
        ArrayNode results = JsonSupport.JSON.createArrayNode();
        for (JsonNode test : cases) {
            ObjectNode result = results.addObject();
            result.put("name", test.path("name").asText());
            try {
                if ("bindings".equals(test.path("action").asText())) {
                    IntegrationBindings.validate(test.get("bindings"),
                            test.get("type"), test.path("computed").asBoolean(false));
                    result.put("value", true);
                    continue;
                }
                TypeSystem.Type type = TypeSystem.compile(test.get("type"));
                JsonNode value;
                switch (test.path("action").asText()) {
                    case "compile" -> value = JsonSupport.JSON.getNodeFactory().booleanNode(true);
                    case "default" -> value = TypeSystem.defaultValue(type, test.get("default"));
                    case "apply" -> {
                        ArrayList<JsonNode> path = new ArrayList<>();
                        if (test.has("path")) test.get("path").forEach(path::add);
                        value = TypeSystem.apply(type, TypeSystem.validate(type, test.get("value")), test.get("default"), path,
                                test.get("op").asText(), test.get("args")).value();
                    }
                    default -> value = TypeSystem.validate(type, test.get("value"));
                }
                result.set("value", value);
            } catch (FieldsException error) {
                result.put("code", error.code());
            }
        }
        System.out.println(results);
    }
}
