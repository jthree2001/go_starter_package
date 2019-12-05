class Home extends React.Component {
  constructor(props) {
    super(props)

    this.state = {
      name: '',
      description: ''
    }
  } 
  onChange = event => {
    this.setState({ [event.target.name]: event.target.value })
  }
  save = () => {
    this.props.mutate({
      variables: {
        name: this.state.name,
        description: this.state.description
      },
      refetchQueries: ['GetNotTodos']
    })
  }  
  render() {
    const { getNotTodos = [] } = this.props.data
    return (
      <div style={{ display: 'flex', justifyContent: 'center', marginTop: '10%' }} >      <div style={{ display: 'flex', flexDirection: 'column' }}>
        <h3 style={{ margin: '0px' }}>Add something to not do!</h3>
        <input placeholder='Name' name='name' onChange={this.onChange} />
        <input placeholder='Description' name='description' onChange={this.onChange} />
        <button onClick={this.save}>Save</button>
      </div>      <table style={{ border: '1px solid black' }}>
          <tr>
            <th style={{ border: '1px solid black' }}>name</th>
            <th style={{ border: '1px solid black' }}>description</th
        </tr>        {
              getNotTodos.map(notTodo => (
                <tr>
                  <td style={{ border: '1px solid black' }}>{notTodo.name}</td>
                  <td style={{ border: '1px solid black' }}>{notTodo.description}</td>
                </tr>
              ))
            }
       </table>
     </div>
        )
      }
}