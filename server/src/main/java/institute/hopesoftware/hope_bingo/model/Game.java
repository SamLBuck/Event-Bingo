package institute.hopesoftware.hope_bingo.model;

import java.util.ArrayList;
import java.util.HashMap;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class Game {

    private ArrayList<Player> players;
    private static Board gameBoard;
    private HashMap<Integer, Board> boardStates;

    
    
        
}
