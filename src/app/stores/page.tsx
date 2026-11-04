import Card from "./_components/Card";

export default function page() {
  const stores = [
    { title: "Store 1", description: "This is the first store.", id: "1" },
    { title: "Store 2", description: "This is the second store.", id: "2" },
  ];
  return (
    <div>
      <h1>Stores</h1>
      <ul>
        {stores.map((store) => (
          <li key={store.id}>
            <Card title={store.title} description={store.description} />
          </li>
        ))}
      </ul>
    </div>
  );
}
