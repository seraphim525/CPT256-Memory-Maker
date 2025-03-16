import SwiftUI
import SwiftData
import AVFoundation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var scores: [Score]
    
    @State private var cards: [String] = []
    @State private var shuffledCards: [String] = []
    @State private var selectedCards: [Int] = []
    @State private var matchedCards: [Int] = []
    @State private var gameWon: Bool = false
    @State private var gridSize: (rows: Int, columns: Int) = (3, 2)
    @State private var showGameSelection = true
    @State private var startTime: Date? = nil
    @State private var elapsedTime: TimeInterval = 0
    @State private var userName: String = ""
    @State private var showNameEntry = false
    @State private var showScores = false
    
    @State private var audioPlayer: AVAudioPlayer?
    @State private var bgMusicPlayer: AVAudioPlayer?
    
    //private let allEmojis = ["😂", "😍", "😭", "😩", "😌", "😎", "🤯", "🥳", "🤓", "🥺", "😤", "🤠", "🫠", "😏", "🤩", "😵"] //Cards as emojis
    
    private let cardImages = ["card1", "card2", "card3", "card4", "card5", "card6", "card7", "card8"] //Cards use images
    
    
    var body: some View {
        ZStack {
            
            
            Image("bg")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
                .blur(radius: 1)
            
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                if showScores {
                    scoreListView
                }
                else if showGameSelection {
                    gameSelectionView
                } else {
                    gameView
                }
            }
        }
        .onAppear {
#if !DEBUG //stops music from playing while in preview mode remove before launching simulator
            playBackgroundMusic(named: "bg_music")
                // Register for app lifecycle events to stop music when the app is backgrounded
            NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
                    stopBackgroundMusic()
                }
                
            NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { _ in
                    stopBackgroundMusic()
                }
#endif
        }
        .onDisappear {
            stopBackgroundMusic()
        }
        
        .alert(isPresented: self.$gameWon) {
            Alert(title: Text("You Win!"), message: Text("Congratulations! You finished in \(String(format: "%.1f", elapsedTime)) seconds."), dismissButton: .default(Text("Play Again")) {
                self.showNameEntry = true
                //self.showGameSelection = true
                }
            )
        }
        
        .sheet(isPresented: $showNameEntry) {
            VStack {
                Text("Your time: \(String(format: "%.1f", elapsedTime)) seconds")
                    .font(.title)
                    .padding()
                Text("Grid size: \(gridSize.rows) x \(gridSize.columns)")
                    .font(.title)
                    .padding()
                Text("Enter your name")
                    .font(.title)
                    .padding()
                TextField("Your Name", text: $userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Button("Save") {
                    saveScore()
                    self.showNameEntry = false
                    self.showGameSelection = true
                }
                .padding()
            }
            .padding()
        }
                  
    }
    
    private var gameSelectionView: some View {
        VStack {
            Text("Memory Matchers")
                .font(.largeTitle.bold())
                .foregroundColor(Color.white)
                .padding()
            Text("Select Game Mode")
                .font(.title.bold())
                .foregroundColor(Color.white)
                .padding()
            
            Button("2 x 3") { startGame(rows: 2, columns: 3) }
                .padding()
                .foregroundColor(Color.white)
                .background(RoundedRectangle(cornerRadius:20).stroke(Color.purple, lineWidth: 4))
                .padding()
            Button("3 x 4") { startGame(rows: 3, columns: 4) }
                .padding()
                .foregroundColor(Color.white)
                .background(RoundedRectangle(cornerRadius:20).stroke(Color.purple, lineWidth: 4))
                .padding()
            Button("4 x 4") { startGame(rows: 4, columns: 4) }
                .padding()
                .foregroundColor(Color.white)
                .background(RoundedRectangle(cornerRadius:20).stroke(Color.purple, lineWidth: 4))
                .padding()
            
            Button("View Scores") {
                withAnimation {
                    self.showScores.toggle()
                }
            }
            .foregroundColor(Color.white)
        }
        .font(.title2)
        .padding()
    }
    
    private var gameView: some View {
        VStack {
            
            Text("Time: \(String(format: "%.1f", elapsedTime)) sec")
                .font(.title2)
                .foregroundColor(Color.white)
                .padding()
            
            GridStack(rows: gridSize.rows, columns: gridSize.columns) { row, col in
                let index = row * gridSize.columns + col
                if index < shuffledCards.count {
                    return AnyView(
                        CardView(symbol: self.shuffledCards[index], isFlipped:
                                    self.selectedCards.contains(index) ||
                                 self.matchedCards.contains(index))
                        .onTapGesture {
                            withAnimation(.smooth){
                                self.cardTapped(index: index)
                            }
                        }
                    )
                } else {
                    return AnyView(EmptyView())
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius:20).stroke(Color.purple, lineWidth: 4))
            .padding()
            
            Button("Restart") {
                withAnimation(.smooth) {
                    self.restartGame()
                }
            }
            .font(.title2)
            .padding()
            .background(Color.purple)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 10)
            
            Button("Return to Game Selction") {
                withAnimation(.smooth) {
                    self.showGameSelection = true
                }
            }
            .font(.title2)
            .padding()
            .background(Color.purple)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 10)
        }
        .onAppear {
            if !gameWon {
                startTime = Date()
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                    if !gameWon {
                        elapsedTime = Date().timeIntervalSince(startTime ?? Date())
                    } else {
                        timer.invalidate()
                    }
                }
            }
        }
    }
    
    // Play custom sound (match, no match)
    func playCustomSound(named soundName: String, withExtension ext: String = "wav") {
        if let soundURL = Bundle.main.url(forResource: soundName, withExtension: ext) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.play()
            } catch {
                print("Error playing sound: \(error.localizedDescription)")
            }
        } else {
            print("Sound file not found")
        }
    }

    // Play background music (looped)
    func playBackgroundMusic(named soundName: String, withExtension ext: String = "wav") {
        if let musicURL = Bundle.main.url(forResource: soundName, withExtension: ext) {
            do {
                bgMusicPlayer = try AVAudioPlayer(contentsOf: musicURL)
                bgMusicPlayer?.numberOfLoops = -1
                bgMusicPlayer?.play()
            } catch {
                print("Error playing background music: \(error.localizedDescription)")
            }
        } else {
            print("Background music file not found")
        }
    }

    // Stop background music
    func stopBackgroundMusic() {
        bgMusicPlayer?.stop()
    }
    
    func startGame(rows: Int, columns: Int) {
        gridSize = (rows, columns)
        let numPairs = (rows * columns) / 2
        //cards = Array(allEmojis.shuffled().prefix(numPairs)) //Use emojis
        cards = Array(cardImages.shuffled().prefix(numPairs)) //Use images
        restartGame()
        showGameSelection = false
        startTime = Date()
        elapsedTime = 0
        
        print("Starting game with grid size: \(rows)x\(columns), Total pairs: \(numPairs)")
    }
    
    func shuffleCards() {
        shuffledCards = (cards + cards).shuffled()
        print("Shuffled Cards: \(shuffledCards)")
    }
    
    func cardTapped(index: Int) {
        if selectedCards.count == 2 {
            return
        }
        
        if !matchedCards.contains(index) {
            selectedCards.append(index)
            if selectedCards.count == 2 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    checkForMatch()
                }
            }
        }
    }
    
    func checkForMatch() {
        let firstIndex = selectedCards[0]
        let secondIndex = selectedCards[1]
        
        if shuffledCards[firstIndex] == shuffledCards[secondIndex] {
            matchedCards += selectedCards
            playCustomSound(named: "match_effect")
            
            if matchedCards.count == shuffledCards.count {
                elapsedTime = Date().timeIntervalSince(startTime ?? Date())
                gameWon = true
            }
        }
        else {
            playCustomSound(named: "no_match")
        }
        selectedCards.removeAll()
    }
    
    func playMatchSound() {
        AudioServicesPlaySystemSound(1104) // Default match sound effect
    }
    
    func restartGame() {
        matchedCards.removeAll()
        selectedCards.removeAll()
        gameWon = false
        shuffleCards()
        startTime = Date()
        elapsedTime = 0
    }
    
    func saveScore() {
        let newScore = Score(name: userName, time: elapsedTime, game: "\(gridSize.rows) x \(gridSize.columns)")
        
        print("Attempting to save score: \(newScore.name), \(newScore.time), \(newScore.game)")
        
        modelContext.insert(newScore)  // Insert new score into SwiftData
        
        do {
            try modelContext.save()
            print("Score saved!")

            // Fetch all scores and print them to debug
            let scores = try modelContext.fetch(FetchDescriptor<Score>())
            print("Saved Scores:")
            for score in scores {
                print("Name: \(score.name), Time: \(score.time), Game Mode: \(score.game)")
            }
        } catch {
            print("Error saving score: \(error.localizedDescription)")
        }
    }

    private var scoreListView: some View {
        VStack {
            Text("Scores")
                .font(.largeTitle.bold())
                .padding()

            List(scores, id: \.id) { score in
                VStack(alignment: .leading) {
                    Text("Name: \(score.name)")
                    Text("Time: \(String(format: "%.1f", score.time)) sec")
                    Text("Game Mode: \(score.game)")
                }
            }
            
            Button("Back") {
                withAnimation {
                    self.showScores = false
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke(Color.purple, lineWidth: 4))
        }
    }
        
}

struct CardView: View {
    var symbol: String
    var isFlipped: Bool
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(isFlipped ? Color.white : Color.purple)
                .frame(width:50, height:70)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 5)
                .overlay (RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray, lineWidth: 2)
                )
            /*if isFlipped { //For emojis
                Text(symbol)
                    .font(.largeTitle)
                    .transition(.scale)
            }*/
            if isFlipped {
                Image(symbol) // Front image (flipped)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 65, height: 85) // Keep it slightly inside the border
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Image("card_back") // Back image (not flipped)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 65, height: 85) // Keep it the same size as the front
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
        }
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
            )
        .animation(.easeInOut(duration: 0.3), value: isFlipped)
    }
}

struct GridStack: View {
    var rows: Int
    var columns: Int
    let content: (Int, Int) -> AnyView
    
    var body: some View {
        VStack(spacing: 10) {
            ForEach(0 ..< rows, id: \ .self) { row in
                HStack(spacing: 10) {
                    ForEach(0..<self.columns, id: \ .self) { column in
                        content(row,column)
                    }
                }
            }
        }
        .onAppear {
            print("GridStack created with \(rows) rows and \(columns) columns")
        }
    }
}

#Preview {
    ContentView()
}
