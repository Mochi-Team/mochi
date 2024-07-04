//
//  DownloadQueueFeature+View.swift
//  
//
//  Created by MochiTeam on 17.05.2024.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import ViewComponents
import Styling

// MARK: - DownloadQueueFeature + View

extension DownloadQueueFeature.View: View {
  @MainActor public var body: some View {
   WithViewStore(store, observe: \.downloadQueue) { viewStore in
     ScrollView {
       ForEach(viewStore.state, id: \.`self`) { item in
         HStack(spacing: 6) {
           FillAspectImage(url: item.image)
             .aspectRatio(3 / 4, contentMode: .fit)
             .cornerRadius(12)
             .frame(height: 80)
           
           VStack(alignment: .leading, spacing: 6) {
               Text("\(item.title)")
               .lineLimit(3)
               .font(.headline.weight(.medium))
               .multilineTextAlignment(.leading)
             Text(item.playlistName)
               .lineLimit(2)
               .font(.caption.weight(.medium))
               .foregroundStyle(.secondary)
               .multilineTextAlignment(.leading)
           }
           
           Spacer()
           switch item.status {
             case .suspended:
               CircularProgressView(progress: item.percentComplete, barStyle: .init(fill: Theme.pastelRed.opacity(0.4), width: 4, blurRadius: 0)) {
                 Image(systemName: "play.fill")
                   .resizable()
                   .aspectRatio(contentMode: .fit)
                   .padding(6)
                   .foregroundStyle(Theme.pastelRed)
               }
               .onTapGesture {
                 viewStore.send(.pause(item))
               }
               .frame(width: 30, height: 30)
               .animation(.easeInOut, value: item.status)
             case .finished:
               Image(systemName: "checkmark.circle")
                 .resizable()
                 .aspectRatio(contentMode: .fit)
                 .frame(width: 29, height: 29)
                 .foregroundStyle(Theme.pastelRed)
                 .animation(.easeInOut, value: item.status)
             case .cancelled:
               Image(systemName: "xmark.circle")
                 .resizable()
                 .aspectRatio(contentMode: .fit)
                 .frame(width: 29, height: 29)
                 .foregroundStyle(Color.secondary.opacity(0.4))
                 .animation(.easeInOut, value: item.status)
             case .downloading:
               CircularProgressView(progress: item.percentComplete, barStyle: .init(fill: Theme.pastelRed, width: 4, blurRadius: 0)) {
                 Image(systemName: "pause.fill")
                   .resizable()
                   .aspectRatio(contentMode: .fit)
                   .padding(6)
                   .foregroundStyle(Theme.pastelRed)
               }
               .frame(width: 30, height: 30)
               .contentShape(Rectangle())
               .onTapGesture {
                 viewStore.send(.pause(item))
               }
               .animation(.easeInOut, value: item.status)
             case .error:
               Image(systemName: "exclamationmark.circle")
                 .resizable()
                 .aspectRatio(contentMode: .fit)
                 .frame(width: 29, height: 29)
                 .foregroundStyle(Theme.pastelRed)
                 .animation(.easeInOut, value: item.status)
           }
         }
         .contentShape(Rectangle())
         .contextMenu {
           Button(role: .destructive) {
             viewStore.send(.didTapCancelDownload(item))
           } label: {
             Label("Cancel Download", systemImage: "xmark")
           }
           .buttonStyle(.plain)
         }
       }
     }
     .frame(maxWidth: .infinity)
     .padding()
     .navigationTitle("Download Queue")
     .onAppear {
       viewStore.send(.didAppear)
     }
   }
  }
}

import OfflineManagerClient
//#Preview {
//  DownloadQueueFeature.View(
//    store: .init(
//      initialState: .init(
//      downloadQueue: [
//        OfflineManagerClient.DownloadingItem(id: URL(string: "_blank")!, percentComplete: 0, image: URL(string: "https://fastly.picsum.photos/id/306/200/300.jpg?hmac=T-FQeWIc7YbLbcYdpyDGypNif0btJ8n5P4ozBJx8WgE")!, playlistName: "downloading", title: "Test 3", epNumber: 1, taskId: 0, status: .downloading),
//        OfflineManagerClient.DownloadingItem(id: URL(string: "_blank")!, percentComplete: 1, image: URL(string: "https://fastly.picsum.photos/id/1006/200/300.jpg?hmac=8H_lylM_UA6ot7bOUTm-ZzZkGKHmdjC-QU4yB3Xo5aQ")!, playlistName: "finished", title: "Test 2", epNumber: 2, taskId: 1, status: .finished),
//        OfflineManagerClient.DownloadingItem(id: URL(string: "_blank")!, percentComplete: 0.35, image: URL(string: "https://fastly.picsum.photos/id/978/200/300.jpg?hmac=sP2_huC-v5a6cNxpdmxp1FPInoDET7j7O3GoftdaEJk")!, playlistName: "suspended", title: "Test 1", epNumber: 3, taskId: 2, status: .suspended)
//      ]
//    ),
//    reducer: { EmptyReducer() }
//  )
//  )
//}
