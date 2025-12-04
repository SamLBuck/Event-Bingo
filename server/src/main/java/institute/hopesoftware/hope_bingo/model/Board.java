package institute.hopesoftware.hope_bingo.model;

import java.util.HashSet;
import java.util.Set;



import io.micrometer.common.lang.NonNull;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import lombok.ToString;

@lombok.Getter
@lombok.Setter
@Entity
public class Board {
    

    @ToString.Include
    @NonNull
    private String boardAuthor;

    @NonNull
    @OneToMany(mappedBy = "board")
    private Set<Question> questions = new HashSet<Question>();

    @NonNull
    @ToString.Include
    private String boardName;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
}
