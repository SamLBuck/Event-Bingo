package institute.hopesoftware.hope_bingo.model;

import java.util.HashMap;
import java.util.Random;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class Game {

    public static int MAX_PLAYERS = 10;
    private Random rand = new Random();

    
    private String gameCode;

    private Board gameBoard;
    private HashMap<String, GameBoard> boardStates = new HashMap<String,GameBoard>();
    private String hostPlayer;
   
    private String password;
    private Boolean isPublic;

    public Game( Board gameBoard, String hostPlayer, Boolean isPublic){
        this.gameCode = String.format("%04d", rand.nextInt(1001));
        this.gameBoard = gameBoard;
        this.isPublic = isPublic;
        
    }

    public Game( Board gameBoard, String hostPlayer, Boolean isPublic, String password){
        this.gameCode = String.format("%04d", rand.nextInt(1001));
        this.gameBoard = gameBoard;
        this.hostPlayer = hostPlayer;
        this.isPublic = isPublic;
        this.password = password;

    }


    public GameBoard addPlayer(String playerName){

        GameBoard gb = new GameBoard(this.gameBoard);
        boardStates.put(playerName, gb);

        return gb;
    }

    
    
    
}
