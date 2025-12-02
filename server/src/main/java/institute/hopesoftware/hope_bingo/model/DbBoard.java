package institute.hopesoftware.hope_bingo.model;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "board", schema = "inspirepractice")
@Getter
@Setter
@NoArgsConstructor
public class DbBoard {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Integer id;

    @Column(name = "boardname", nullable = false)
    private String boardName;

    @Column(name = "ceatedby", nullable = false)
    private String createdBy;

    @Column(name = "description")
    private String description;

    @Column(name = "datecreated", nullable = false, updatable = false, insertable = false)
    private LocalDateTime dateCreated;

    public DbBoard(String boardName, String createdBy, String description) {
        this.boardName = boardName;
        this.createdBy = createdBy;
        this.description = description;
    }
}
