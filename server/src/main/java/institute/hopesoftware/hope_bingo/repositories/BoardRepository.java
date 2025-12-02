package institute.hopesoftware.hope_bingo.repositories;

import org.springframework.data.repository.CrudRepository;
import institute.hopesoftware.hope_bingo.model.Board;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import institute.hopesoftware.hope_bingo.model.DbBoard;

@Repository
public interface BoardRepository extends JpaRepository<DbBoard, Integer> {

    Optional<DbBoard> findByBoardName(String boardName);

    List<DbBoard> findAllByCreatedBy(String createdBy);
}
