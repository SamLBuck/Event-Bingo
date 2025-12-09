package institute.hopesoftware.hope_bingo.services;

public class gameRequests {

    public static record NewGameRequest (String hostPlayerName, Integer boardId, Boolean isPublic, String password) { }
    public static record JoinGameRequest (String playerName, String password) { }
}
