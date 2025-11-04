package institute.hopesoftware.hope_bingo.model;

import java.util.Set;

@lombok.Getter
@lombok.Setter
public class Board {
    
    private String boardAuthor;
    private String boardName;
    private String[][] questionGrid;
    public static final int GRID_SIZE = 5;

    public Board(String boardAuthor, String boardName, String[][] questionGrid) {
        this.boardAuthor = boardAuthor;
        this.boardName = boardName;
        this.questionGrid = questionGrid;
    }


    public void composeBoard(Set<String> questions) {


        if (questions.size() < (GRID_SIZE * GRID_SIZE) -1) {
            throw new IllegalArgumentException("Not enough questions to fill the board.");
        }

        String[] questionArray = questions.toArray(new String[24]);
        int index = 0;

        for (int i = 0; i < GRID_SIZE; i++) {
            for (int j = 0; j < GRID_SIZE; j++) {
                questionGrid[i][j] = questionArray[index++];
            }
        }
    }
}
