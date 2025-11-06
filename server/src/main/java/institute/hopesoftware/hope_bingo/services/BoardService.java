package institute.hopesoftware.hope_bingo.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;
import org.springframework.stereotype.Service;

import institute.hopesoftware.hope_bingo.model.Board;
import institute.hopesoftware.hope_bingo.repositories.BoardRepository;

@Service
public class BoardService {

    @Autowired private final BoardRepository boardRepository;

    public BoardService(BoardRepository boardRepository) {
        this.boardRepository = boardRepository;
    }

    
    
}
