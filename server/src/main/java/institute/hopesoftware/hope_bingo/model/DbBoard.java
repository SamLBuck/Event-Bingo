package institute.hopesoftware.hope_bingo.model;
import java.util.HashSet;

public record DbBoard(
    Integer boardId,
    String boardAuthor,
    String boardName,
    HashSet<String> questions
) {}