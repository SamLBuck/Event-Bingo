package institute.hopesoftware.hope_bingo.controllers;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

import institute.hopesoftware.hope_bingo.model.Game;
import institute.hopesoftware.hope_bingo.services.GameService;
import institute.hopesoftware.hope_bingo.services.gameRequests.*;
import institute.hopesoftware.hope_bingo.services.gameResponses.*;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;



@RestController
@RequestMapping("/api/games")
public class GameController {



    @Autowired
    private GameService gameService;

    @PostMapping(value="")
    public ResponseEntity<NewGameResponse> newGame(@RequestBody NewGameRequest request) {
        Integer boardId = request.boardId();
        String hostPlayerName = request.hostPlayerName();
        Integer playerUUID = request.playerUUID();
        Game Game = gameService.createNewGame(boardId, playerUUID, hostPlayerName);


        NewGameResponse response = new NewGameResponse(Game.getKey());
        return ResponseEntity.ok(response);
        
    }
     


    @GetMapping(value="")
    public ResponseEntity<ListGamesResponse> listGames() {
        List<Game> games = gameService.getGames();
        ListGamesResponse response = new ListGamesResponse(games);
        return ResponseEntity.ok(response);

    }    
        
}


    
