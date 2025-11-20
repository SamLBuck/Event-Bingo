package institute.hopesoftware.hope_bingo.services;

import java.util.List;

public record Requests() {
    public record NewBoardRequest(List<String> questions, Boolean isPrivate, String gameTitle){}
    public record getBoardsRequest(String playerUuid){}
}
