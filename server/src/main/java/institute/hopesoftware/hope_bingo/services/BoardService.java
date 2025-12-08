package institute.hopesoftware.hope_bingo.services;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import institute.hopesoftware.hope_bingo.model.Board;
import institute.hopesoftware.hope_bingo.model.Question;
import institute.hopesoftware.hope_bingo.repositories.BoardRepository;
import institute.hopesoftware.hope_bingo.repositories.QuestionRepository;
import lombok.NoArgsConstructor;

@Service
@NoArgsConstructor
public class BoardService {

    @Autowired
    private BoardRepository boardRepository;

    @Autowired
    private QuestionRepository questionRepository;

    public BoardService(BoardRepository boardRepository) {
        this.boardRepository = boardRepository;
    }

    public Board createNewBoard(Set<String> questions, String gameTitle, String author, String description){
    Board board = new Board();
    board.setDescription(description);

        board.setBoardName(gameTitle);

        if (author == null || author.isBlank()) {
            board.setBoardAuthor("author");
        } else {
            board.setBoardAuthor(author);
        }

        boardRepository.save(board);

        for (String q : questions) {
            Question question = new Question(q);
            question.setBoard(board);
            questionRepository.save(question);
        }
  

        return board;
    }

    public List<Board> getBoards() {
        List<Board> boards = new ArrayList<>();
        boardRepository.findAll().forEach(boards::add);
        return boards;
    }
    public Board findBoardByName(String name) {
        return boardRepository.findByBoardName(name);
    }
    
    public List<Board> findAllBoardsByName(String name) {
        return boardRepository.findAllByBoardAuthor(name);
    }
    }
