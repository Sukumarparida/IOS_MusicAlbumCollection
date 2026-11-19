import Foundation

/// Provides curated sample albums used on first launch or in previews.
struct SampleDataService: Sendable {
    static func makeSampleAlbums() -> [Album] {
        let now = Date()
        return [
            Album(
                name: "Roja",
                artist: "A. R. Rahman",
                genre: .film,
                releaseYear: 1992,
                musicDirector: "A. R. Rahman",
                trackCount: 6,
                favouriteTrack: "Chinna Chinna Aasai",
                dateAdded: now.addingTimeInterval(-400)
            ),
            Album(
                name: "Abbey Road",
                artist: "The Beatles",
                genre: .rock,
                releaseYear: 1969,
                musicDirector: "George Martin",
                trackCount: 17,
                favouriteTrack: "Come Together",
                dateAdded: now.addingTimeInterval(-300)
            ),
            Album(
                name: "Thriller",
                artist: "Michael Jackson",
                genre: .pop,
                releaseYear: 1982,
                musicDirector: "Quincy Jones",
                trackCount: 9,
                favouriteTrack: "Billie Jean",
                dateAdded: now.addingTimeInterval(-200)
            ),
            Album(
                name: "The Four Seasons",
                artist: "Antonio Vivaldi",
                genre: .classical,
                releaseYear: 1989,
                musicDirector: "Antonio Vivaldi",
                trackCount: 12,
                favouriteTrack: "Spring",
                dateAdded: now.addingTimeInterval(-100)
            ),
            Album(
                name: "Suprabhatam",
                artist: "M. S. Subbulakshmi",
                genre: .devotional,
                releaseYear: 1963,
                musicDirector: "M. S. Subbulakshmi",
                trackCount: 4,
                favouriteTrack: "Kausalya Supraja",
                dateAdded: now
            )
        ]
    }
}
