package institute.hopesoftware.hope_bingo.controllers;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import institute.hopesoftware.hope_bingo.Board;
import institute.hopesoftware.hope_bingo.services.BoardService;
import institute.hopesoftware.hope_bingo.services.Requests.NewBoardRequest;
import institute.hopesoftware.hope_bingo.services.Responses.GetBoardsResponse;
import institute.hopesoftware.hope_bingo.services.Responses.NewBoardResponse;

@RestController
@RequestMapping("/api")
public class BoardController {

    private final BoardService boardService;
    public BoardController(BoardService boardService) {
        this.boardService = boardService;
    }

@PostMapping(value="boards")
public ResponseEntity<NewBoardResponse> newBoard(@RequestBody NewBoardRequest request) 
{
    Board board = boardService.newGame(request.questions(), request.isPrivate(), request.gameTitle());        
    NewBoardResponse response = new NewBoardResponse(board.getId());        
    return ResponseEntity.ok(response);
}
@GetMapping("boards")
public ResponseEntity<GetBoardsResponse> getBoards() {
    List<Board> boards = boardService.getBoards();
    return ResponseEntity.ok(new GetBoardsResponse(boards));
}
}