package institute.hopesoftware.hope_bingo.services;

import java.util.ArrayList;
import java.util.HashMap;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import institute.hopesoftware.hope_bingo.model.Board;
import institute.hopesoftware.hope_bingo.model.Game;
import institute.hopesoftware.hope_bingo.model.Player;
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

    private ArrayList<Game> games = new ArrayList<>();

    public Game createNewGame(Integer boardId, Integer playerUUID, String hostPlayerName) {
        Game newGame = new Game();
        Board boardTemplate = boardRepository.findById(boardId).orElse(null);
        if (boardTemplate == null) {
            throw new IllegalArgumentException("Board with id " + boardId + " does not exist.");
        }

        // Initialize static DbBoard for the game
        
        newGame.setPlayers(new ArrayList<>());
        newGame.setBoardStates(new HashMap<>());

        games.add(newGame);
        return newGame;
    }

    public Game joinGame(Integer gameKey, Integer playerUUID, String playerName, String password) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("Unimplemented method 'joinGame'");
    }

    

}
