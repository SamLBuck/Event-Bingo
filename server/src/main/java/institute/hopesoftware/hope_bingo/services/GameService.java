package institute.hopesoftware.hope_bingo.services;

import java.util.ArrayList;
import java.util.HashMap;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import institute.hopesoftware.hope_bingo.model.Board;
import institute.hopesoftware.hope_bingo.model.Game;
import institute.hopesoftware.hope_bingo.model.GameBoard;
import institute.hopesoftware.hope_bingo.repositories.BoardRepository;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Service
@Getter
@Setter
@NoArgsConstructor
public class GameService {
    
    @Autowired
    private BoardRepository boardRepository;

    private ArrayList<Game> games = new ArrayList<Game>();

    @SuppressWarnings("null")
    public Game createNewGame(Integer bID, String hostPlayerName, Boolean isPublic, String password){

        Board board = boardRepository.findById(bID).get();

        if(board == null){
            throw new IllegalArgumentException("Board with ID " + bID + " does not exist.");
        }

        Game game;
        if (password.isEmpty()){
             game = new Game(board, hostPlayerName, isPublic);
        }else{
             game = new Game(board, hostPlayerName, isPublic, password);
        }


           games.add(game);


        return game;

    }

    public GameBoard joinGame(String gameCode, String playerName, String password){
        // Find the game with the given gameCode
        for (Game game : games) {
            if (game.getGameCode().equals(gameCode)) {
                if( game.getPassword() != null){
                    if(game.getPassword().equals(password))
                    // Check if the password matches
                    {
                        if (!game.getBoardStates().containsKey(playerName)) {
                            return game.addPlayer(playerName);
                        }else{
                            throw new institute.hopesoftware.hope_bingo.exceptions.DuplicatePlayerException("Player name already exists in the game.");
                        }
                    }
                }else{
                    if (!game.getBoardStates().containsKey(playerName)) {
                            return game.addPlayer(playerName);
                        }else{
                            throw new institute.hopesoftware.hope_bingo.exceptions.DuplicatePlayerException("Player name already exists in the game.");
                        }
                }
                // Attempt to join the game
                
            }
        }

        throw new IllegalArgumentException("Game not found or incorrect password.");
        // If no game is found, return null or throw an exception as needed
        
    }

    public HashMap<String,GameBoard> getGameBoard(String gameCode){
        for (Game game : games) {
            if (game.getGameCode().equals(gameCode)) {
                return game.getBoardStates();
            }
        }
        throw new IllegalArgumentException("Game not found.");
    }


}