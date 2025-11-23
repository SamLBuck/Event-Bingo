package institute.hopesoftware.hope_bingo.model;

import java.util.Set;



import io.micrometer.common.lang.NonNull;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Transient;

import lombok.EqualsAndHashCode;
import lombok.ToString;

@lombok.Getter
@lombok.Setter
@Entity
public class Board {
    

    @ToString.Include
    @NonNull
    @EqualsAndHashCode.Include
    private String boardAuthor;

    @EqualsAndHashCode.Include
    @NonNull
    @ToString.Include
    private String boardName;

    @Transient
    private String[][] questionGrid;

    @Transient
    public static final int GRID_SIZE = 5;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    public Board(String boardAuthor, String boardName) {
        this.boardAuthor = boardAuthor;
        this.boardName = boardName;
        this.questionGrid = new String[GRID_SIZE][GRID_SIZE];
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
