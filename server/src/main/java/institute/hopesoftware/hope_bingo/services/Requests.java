package institute.hopesoftware.hope_bingo.services;

import java.util.Set;


public record Requests() {
    public record NewBoardRequest(Set<String> questions, String boardName, String author){}
    public record getBoardsRequest(){}
}
