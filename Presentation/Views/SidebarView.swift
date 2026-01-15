import SwiftUI

// MARK: - SidebarView

public struct SidebarView: View {
    public enum SidebarItem: String, Identifiable, CaseIterable {
        case allWords = "전체 단어"
        case favorites = "즐겨찾기"
        case trash = "휴지통"
        case settings = "설정"
        
        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .allWords: return "book.fill"
            case .favorites: return "star.fill"
            case .trash: return "trash.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    @Binding public var selection: SidebarItem?
    
    public init(selection: Binding<SidebarItem?>) {
        self._selection = selection
    }
    
    public var body: some View {
        List(selection: $selection) {
            ForEach(SidebarItem.allCases) { item in
                SidebarItemRow(item: item, selection: $selection)
                    .tag(item)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .frame(minWidth: 200)
        .padding(.top, 8)
    }
}

// MARK: - SidebarItemRow

private struct SidebarItemRow: View {
    let item: SidebarView.SidebarItem
    @Binding var selection: SidebarView.SidebarItem?
    
    private var isSelected: Bool {
        selection == item
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(width: 20, height: 20)
            
            Text(item.rawValue)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .contentShape(Rectangle())
    }
}
