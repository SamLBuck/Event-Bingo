package institute.hopesoftware.hope_bingo.repositories;

import org.springframework.data.repository.CrudRepository;

import institute.hopesoftware.hope_bingo.model.Question;

public interface QuestionRepository extends CrudRepository<Question, Integer> {

    public Question findByBoardId(Integer board_id);

}
