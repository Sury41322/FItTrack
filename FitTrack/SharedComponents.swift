//
//  SharedComponents.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import SwiftUI

// MARK: - MiniMacro

struct MiniMacro: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text("\(value)g")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - MacroLabel

struct MacroLabel: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)g")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
