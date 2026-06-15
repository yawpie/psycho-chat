(async ()=> {
  const createdMessage = await fetch("http://localhost:3000/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      sender: "johndoe",
      receiver: "janedoe",
      text: "Hello, Jane!",
    }),
  }).then((res) => res.json());
  console.log("Created messages:", createdMessage);
})()