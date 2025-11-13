package institute.hopesoftware.hope_bingo.controllers;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

import institute.hopesoftware.hope_bingo.model.Game;
import institute.hopesoftware.hope_bingo.services.GameService;
import institute.hopesoftware.hope_bingo.services.gameRequests.*;
import institute.hopesoftware.hope_bingo.services.gameResponses.*;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;



@RestController("/api/games/")
public class GameController {




    private GameService gameService;

    @PostMapping(value="/{key}/")
    public ResponseEntity<NewGameResponse> newGame(@RequestBody NewGameRequest request, @PathVariable Integer key) {
        Integer boardId = request.boardId();
        String hostPlayerName = request.hostPlayerName();
        Integer playerUUID = request.playerUUID();
        Game Game = gameService.createNewGame(boardId, playerUUID, hostPlayerName);


        NewGameResponse response = new NewGameResponse(Game.getKey());
        return ResponseEntity.ok(response);
        
    }
    

    @PostMapping(value="/{key}/")
    public ResponseEntity<JoinGameResponse> postMethodName(@RequestBody JoinGameRequest request, @PathVariable Integer key) {
        
        Integer playerUUID = request.playerUUID();
        String playerName = request.playerName();
        String password = request.password();
        Integer gameKey = key;

        gameService.joinGame(gameKey, playerUUID, playerName, password);

        JoinGameResponse response = new JoinGameResponse(gameKey);
        return ResponseEntity.ok(response);
    }

    @GetMapping(value="")
    public ResponseEntity<ListGamesResponse> listGames() {
        List<Game> games = gameService.getGames();
        ListGamesResponse response = new ListGamesResponse(games);
        return ResponseEntity.ok(response);

    }
    
    
    
}


    
