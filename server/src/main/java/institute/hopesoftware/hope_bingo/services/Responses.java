package institute.hopesoftware.hope_bingo.services;

import java.util.List;

import institute.hopesoftware.hope_bingo.model.Board;

public class Responses {
    public record NewBoardResponse(Integer id){}
    public record GetBoardsResponse (List<Board> boards) {}
}
