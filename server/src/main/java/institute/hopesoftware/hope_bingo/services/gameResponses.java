package institute.hopesoftware.hope_bingo.services;
import java.util.List;
import institute.hopesoftware.hope_bingo.model.Game;

public class gameResponses {

    public static record NewGameResponse (Integer key) { }
    public static record JoinGameResponse (Integer key) { }
    public static record ListGamesResponse (List<Game> games) { }
}
