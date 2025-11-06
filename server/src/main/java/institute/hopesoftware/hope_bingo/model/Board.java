package institute.hopesoftware.hope_bingo.model;

import java.util.HashSet;

@lombok.Getter
@lombok.Setter
public class Board {
    
    private String boardAuthor;
    private String boardName;
    private HashSet<String> questionGrid;

    //@TODO refactor to store questions as a Set only, using composeBoard to fill the grid when needed

    public Board(String boardAuthor, String boardName) {
        this.boardAuthor = boardAuthor;
        this.boardName = boardName;
        this.questionGrid = new HashSet<String>();
    }


}