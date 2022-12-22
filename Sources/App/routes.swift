import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    app.get("leaks") { req async throws -> String in
        for i in 0..<100 {
            let todo = Todo(title: "\(i)")
            try await todo.save(on: req.db)
            try await Task.sleep(for: .seconds(1))
        }
        
        return "ok"
    }

    try app.register(collection: TodoController())
}
