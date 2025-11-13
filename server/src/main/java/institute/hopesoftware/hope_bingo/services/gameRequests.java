package institute.hopesoftware.hope_bingo.services;

public class gameRequests {

    public static record NewGameRequest (String hostPlayerName, Integer boardId, Integer playerUUID) { }
    public static record JoinGameRequest (String playerName, String password, Integer playerUUID) { }
}
