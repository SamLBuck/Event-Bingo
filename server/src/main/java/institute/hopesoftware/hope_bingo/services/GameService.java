package institute.hopesoftware.hope_bingo.services;

import java.util.ArrayList;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import institute.hopesoftware.hope_bingo.model.Board;
import institute.hopesoftware.hope_bingo.model.Game;
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

    @SuppressWarnings("null")
    public Game createNewGame(Integer bID, String hostPlayerName, Boolean isPublic, String password){

        Board board = boardRepository.findById(bID).get();
        Game game;
        if (password.isEmpty()){
             game = new Game(board, hostPlayerName, isPublic);
        }else{
             game = new Game(board, hostPlayerName, isPublic, password);
        }

    

        return game;

    }


}