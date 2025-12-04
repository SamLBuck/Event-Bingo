package institute.hopesoftware.hope_bingo.repositories;

import org.springframework.data.repository.CrudRepository;
import institute.hopesoftware.hope_bingo.model.Board;
import java.util.List;


public interface BoardRepository extends CrudRepository<Board, Integer> {

    public Board findByBoardName(String boardName);

    public List<Board> findAllByBoardAuthor(String boardAuthor);

}
