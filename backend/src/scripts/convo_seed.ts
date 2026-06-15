(async () => {
  const newConvo = await fetch("http://localhost:3000/convo/create", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      user1: "johndoe",
      user2: "janedoe",
    }),
  }).then((res) => res.json());
  console.log("Created conversation:", newConvo);
})();
