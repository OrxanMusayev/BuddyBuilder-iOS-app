import SwiftUI

// MARK: - Events Filter View
struct EventsFilterView: View {
    @ObservedObject var viewModel: EventsViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            EventFiltersSheet(viewModel: viewModel)
                .environmentObject(localizationManager)
                .navigationTitle("Filters")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("Clear All") {
                        viewModel.clearFilters()
                        presentationMode.wrappedValue.dismiss()
                    },
                    trailing: Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
        }
    }
}
