import React from 'react'
import { gql } from 'apollo-boost';
import { graphql, compose } from 'react-apollo';
// example of a graphql query
const query = gql`
  query GetNotTodos{
    getNotTodos {
      name
      description
    }
  }`
  // example of a graphql mutation
const mutation = gql`
  mutation CreateNotTodo($name: String, $description: String) {
    createNotTodo(name: $name, description: $description) {
      name
      description
    }
  }`
@compose(
  graphql(query),
  graphql(mutation)
)
class Home extends React.Component {
  render() {
    console.log(this.props)
    return (
      <div>
        Home still!
     </div>
    )
  }
} export default Home