package institute.hopesoftware.hope_bingo.services;
import java.util.HashMap;
import java.util.List;
import institute.hopesoftware.hope_bingo.model.Game;
import institute.hopesoftware.hope_bingo.model.GameBoard;

public class gameResponses {

    public static record NewGameResponse (String gameCode) { }
    public static record JoinGameResponse (GameBoard boardstate) { }
    public static record GameStateResponse (HashMap<String,GameBoard> boardStates) { }
    public static record ListGamesResponse (List<Game> games) { }
}
