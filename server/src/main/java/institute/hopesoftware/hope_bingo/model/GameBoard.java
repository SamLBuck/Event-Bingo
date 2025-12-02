package institute.hopesoftware.hope_bingo.model;

import java.util.Set;

import java.util.Iterator;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class GameBoard {


    private static final int GRID_SIZE = 5;

    private String[][] questionGrid;

    private String authorName;

    public GameBoard(Board board){

        this.authorName = board.getBoardAuthor();
        this.questionGrid = composeBoard(board.getQuestions());
    }


    public String[][] composeBoard(Set<Question> questions){

        String[][] grid = new String[GRID_SIZE][GRID_SIZE];

        Iterator<Question> it = questions.iterator();
        for (int i = 0; i < GRID_SIZE; i++ ){
            for(int j = 0; j < GRID_SIZE; j++){
                grid[i][j] = it.next().getText();
            }
        }
        
        return grid;
    }



}
