package institute.hopesoftware.hope_bingo.model;

import java.util.HashSet;
import java.util.Set;

import com.fasterxml.jackson.annotation.JsonManagedReference;

import io.micrometer.common.lang.NonNull;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import lombok.AccessLevel;
import lombok.ToString;

@lombok.Getter
@lombok.Setter
@Entity
public class Board {
    

    @ToString.Include
    @NonNull
    @Column(name = "author")
    private String boardAuthor;

    
    @OneToMany(mappedBy = "board", fetch = jakarta.persistence.FetchType.EAGER)
    @lombok.Setter(AccessLevel.PROTECTED)
    @JsonManagedReference
    private Set<Question> questions = new HashSet<Question>();

    @NonNull
    @Column(name = "name")
    @ToString.Include
    private String boardName;

    @Column(name = "description")
    @ToString.Include
    private String description;


    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

   
}
