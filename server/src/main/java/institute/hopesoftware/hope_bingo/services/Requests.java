package institute.hopesoftware.hope_bingo.services;

import java.util.List;
import java.util.Set;

import institute.hopesoftware.hope_bingo.model.Question;

public record Requests() {
    public record NewBoardRequest(Set<Question> questions, String gameTitle, String author){}
    public record getBoardsRequest(){}
}
