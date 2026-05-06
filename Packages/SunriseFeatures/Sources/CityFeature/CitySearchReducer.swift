import Foundation
import ComposableArchitecture
import SunriseCore

@Reducer
public struct CitySearchReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var query: String = ""
        public var results: [CitySearchResult] = []
        public var isResolving = false
        public var error: String?

        public init() {}
    }

    public enum Action: Sendable {
        case queryChanged(String)
        case resultsUpdated([CitySearchResult])
        case selectResult(CitySearchResult)
        case cityResolved(Result<City, ResolveError>)
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case cityResolved(City)
        }
    }

    public struct ResolveError: Error, Equatable, Sendable {
        public let message: String
        public init(_ error: any Error) { self.message = String(describing: error) }
    }

    @Dependency(\.searchClient) var search

    public init() {}

    private enum CancelID { case stream }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .queryChanged(query):
                state.query = query
                state.error = nil
                guard !query.isEmpty else {
                    state.results = []
                    return .cancel(id: CancelID.stream)
                }
                return .run { send in
                    for await results in search.autocomplete(query: query) {
                        await send(.resultsUpdated(results))
                    }
                }
                .cancellable(id: CancelID.stream, cancelInFlight: true)

            case let .resultsUpdated(results):
                state.results = results
                return .none

            case let .selectResult(result):
                state.isResolving = true
                state.error = nil
                return .run { send in
                    do {
                        let city = try await search.resolve(result: result)
                        await send(.cityResolved(.success(city)))
                    } catch {
                        await send(.cityResolved(.failure(ResolveError(error))))
                    }
                }

            case let .cityResolved(.success(city)):
                state.isResolving = false
                return .send(.delegate(.cityResolved(city)))

            case let .cityResolved(.failure(error)):
                state.isResolving = false
                state.error = error.message
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
