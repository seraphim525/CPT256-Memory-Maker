//
//  ContentView.swift
//  Memory Matchers
//
//  Created by Justin Whitt on 3/8/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @State private var cards = ["😂", "😍", "😭", "😩", "😌", "😎"]
    @State private var shuffledCards: [String] = []
    @State private var selectedCards: [Int] = []
    @State private var matchedCards: [Int] = []
    
    @State private var gameWon: Bool = false
    var body: some View {
        VStack {
            Text("Memory Matchers")
                .font(.largeTitle.bold())
                .padding()
            
            GridStack(rows: 2, columns: 6) { row, col in
                
                let index = row * 6 + col
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
        }
        .onAppear(perform: shuffleCards)
        .alert(isPresented: self.$gameWon) {
            Alert(title: Text("You Win!"), message: Text("Congratulations, you have won the game!"), dismissButton: .default(Text("Play Again"), action: {
                withAnimation(.smooth) {
                    self.restartGame()
                }
            }))
        }
    }
    
    func shuffleCards() {
        shuffledCards = (cards + cards).shuffled()
    }
    
    func cardTapped(index: Int) {
        if selectedCards.count == 2 {
            selectedCards.removeAll()
        }
        
        if !matchedCards.contains(index) {
            selectedCards.append(index)
            if selectedCards.count == 2 {
                checkForMatch()
            }
        }
    }
    
    func checkForMatch() {
        let firstIndex = selectedCards[0]
        let secondIndex = selectedCards[1]
        if shuffledCards[firstIndex] == shuffledCards[secondIndex] {
            matchedCards += selectedCards
            if matchedCards.count == shuffledCards.count {
                gameWon = true
            }
        }
    }
    
    func restartGame() {
        matchedCards.removeAll()
        selectedCards.removeAll()
        shuffleCards()
    }
}



#Preview {
    ContentView()
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
            if isFlipped {
                Text(symbol)
                    .font(.largeTitle)
                    .transition(.scale)
            }
            
        }
    }
}


struct GridStack: View {
    var rows: Int
    var columns: Int
    let content: (Int, Int) -> AnyView
    
    var body: some View {
        
        VStack(spacing: 10) {
            ForEach(0 ..< rows, id: \.self) { row in
                
                HStack(spacing: 10) {
                    ForEach(0..<self.columns, id: \.self) { column in
                        content(row,column)
                    }
                }
            }
        }
    }
}
