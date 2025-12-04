package institute.hopesoftware.hope_bingo.services;
import java.util.List;
import institute.hopesoftware.hope_bingo.model.Game;

public class gameResponses {

    public static record NewGameResponse (String gameCode) { }
    public static record JoinGameResponse (String GameCode) { }
    public static record ListGamesResponse (List<Game> games) { }
}
