package institute.hopesoftware.hope_bingo.controllers;

import java.util.HashMap;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

import institute.hopesoftware.hope_bingo.exceptions.DuplicatePlayerException;
import institute.hopesoftware.hope_bingo.model.Game;
import institute.hopesoftware.hope_bingo.model.GameBoard;
import institute.hopesoftware.hope_bingo.services.GameService;
import institute.hopesoftware.hope_bingo.services.gameRequests.*;
import institute.hopesoftware.hope_bingo.services.gameResponses.*;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;



@RestController
@RequestMapping("/api/games")
public class GameController {



    @Autowired
    private GameService gameService;

    @PostMapping(value="")
    public ResponseEntity<NewGameResponse> newGame(@RequestBody NewGameRequest request) {
        Integer boardId = request.boardId();
        String hostPlayerName = request.hostPlayerName();
        Boolean isPublic = request.isPublic();
        String password = request.password();

        try{
        Game Game = gameService.createNewGame(boardId, hostPlayerName, isPublic, password);
        NewGameResponse response = new NewGameResponse(Game.getGameCode());
        return ResponseEntity.ok(response);
        }catch(IllegalArgumentException e){
            return ResponseEntity.status(404).build();
        }
        
    }
     


    @GetMapping(value="")
    public ResponseEntity<ListGamesResponse> listGames() {
        List<Game> games = gameService.getGames();
        ListGamesResponse response = new ListGamesResponse(games);
        return ResponseEntity.ok(response);

    }    
    
    @PostMapping(value="/{gameCode}/join")
    public ResponseEntity<JoinGameResponse> joinGame(@RequestBody JoinGameRequest request, @PathVariable String gameCode) {
        String playerName = request.playerName();
        String password = request.password();
        Integer playerUUID = request.playerUUID();

        try{

            GameBoard gb = gameService.joinGame(gameCode, playerName, password, playerUUID);
            JoinGameResponse response = new JoinGameResponse(gb);
            return ResponseEntity.ok(response);

        }catch(DuplicatePlayerException e){
            return ResponseEntity.status(400).build();
        }catch(IllegalArgumentException e){
            return ResponseEntity.status(404).build();
        }

        
    }


    @GetMapping(value="/{gameCode}/")
    public ResponseEntity<GameStateResponse> gameState(@PathVariable String gameCode) {
        try{
            HashMap<String,GameBoard> boardStates = gameService.getGameBoard(gameCode);
            GameStateResponse response = new GameStateResponse(boardStates);
            return ResponseEntity.ok(response);
        }catch(IllegalArgumentException e){
            return ResponseEntity.status(404).build();
        }
    }


}


    
