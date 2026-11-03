import { useCallback, useEffect, useState } from "react";
import { supabase } from "./supabaseClient";

type Conversation = {
  id: string;
  rfq_id: string;
  manufacturer_id: string;
  buyer_id: string;
  supplier_owner_id: string;
  updated_at: string;
  rfq_targets?: { manufacturers?: { name?: string } | null } | null;
};
type Message = { id: string; conversation_id: string; sender_id: string; body: string; created_at: string; read_at: string | null };

export default function MessagingPanel({ userId, accountType }: { userId: string; accountType: "buyer" | "supplier" }) {
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [selectedId, setSelectedId] = useState("");
  const [messages, setMessages] = useState<Message[]>([]);
  const [draft, setDraft] = useState("");
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState("");
  const [loading, setLoading] = useState(false);

  const loadConversations = useCallback(async () => {
    if (!supabase) return;
    setLoading(true);
    const column = accountType === "buyer" ? "buyer_id" : "supplier_owner_id";
    const { data, error } = await supabase.from("rfq_conversations")
      .select("id,rfq_id,manufacturer_id,buyer_id,supplier_owner_id,updated_at,rfq_targets(manufacturers(name))")
      .eq(column, userId).order("updated_at", { ascending: false });
    if (error) setNotice("Conversations could not be loaded. Please refresh.");
    else {
      const rows = (data || []) as Conversation[];
      setConversations(rows);
      if (!selectedId && rows.length) setSelectedId(rows[0].id);
      if (selectedId && !rows.some(row => row.id === selectedId)) setSelectedId(rows[0]?.id || "");
    }
    setLoading(false);
  }, [accountType, userId, selectedId]);

  const loadMessages = useCallback(async () => {
    if (!supabase || !selectedId) { setMessages([]); return; }
    const { data, error } = await supabase.from("rfq_messages")
      .select("id,conversation_id,sender_id,body,created_at,read_at")
      .eq("conversation_id", selectedId).order("created_at", { ascending: true }).limit(200);
    if (error) { setNotice("Messages could not be loaded. Please refresh."); return; }
    const rows = (data || []) as Message[];
    setMessages(rows);
    const unreadIds = rows.filter(row => row.sender_id !== userId && !row.read_at).map(row => row.id);
    if (unreadIds.length) {
      await supabase.from("rfq_messages").update({ read_at: new Date().toISOString() })
        .in("id", unreadIds).neq("sender_id", userId);
    }
  }, [selectedId, userId]);

  useEffect(() => { void loadConversations(); }, [loadConversations]);
  useEffect(() => { void loadMessages(); }, [loadMessages]);

  const sendMessage = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!supabase || !selectedId || !draft.trim() || busy) return;
    setBusy(true); setNotice("");
    const { error } = await supabase.from("rfq_messages").insert({
      conversation_id: selectedId, sender_id: userId, body: draft.trim()
    });
    if (error) setNotice("Message could not be sent. Please try again.");
    else { setDraft(""); await loadMessages(); await loadConversations(); }
    setBusy(false);
  };

  return <section className="buyer-workspace messaging-panel" aria-label="Marketplace messages">
    <div className="messaging-heading">
      <div><h3>Messages</h3><p className="account-copy">Private conversations linked to your sourcing requests.</p></div>
      <button type="button" onClick={() => { void loadConversations(); void loadMessages(); }} disabled={loading}>Refresh</button>
    </div>
    {notice && <p className="account-message" role="status">{notice}</p>}
    {conversations.length === 0 ? <p className="account-copy">{loading ? "Loading conversations…" : "No conversations yet. Conversations become available when an RFQ is matched with an approved supplier."}</p> : <div className="messaging-layout">
      <nav className="conversation-list" aria-label="Conversations">
        {conversations.map((conversation) => <button type="button" key={conversation.id}
          className={selectedId === conversation.id ? "conversation-choice active" : "conversation-choice"}
          aria-pressed={selectedId === conversation.id} onClick={() => setSelectedId(conversation.id)}>
          <b>{accountType === "buyer" ? (conversation.rfq_targets?.manufacturers?.name || "Supplier conversation") : "Buyer request"}</b>
          <span>RFQ {conversation.rfq_id.slice(0, 8).toUpperCase()}</span>
          <small>{new Date(conversation.updated_at).toLocaleDateString()}</small>
        </button>)}
      </nav>
      <div className="message-thread">
        <div className="message-history" aria-live="polite">
          {messages.length === 0 ? <p className="account-copy">No messages yet. Start the conversation below.</p> : messages.map(message => <article key={message.id} className={message.sender_id === userId ? "message-bubble mine" : "message-bubble"}>
            <p>{message.body}</p><time dateTime={message.created_at}>{new Date(message.created_at).toLocaleString()}</time>
          </article>)}
        </div>
        <form className="message-compose" onSubmit={sendMessage}>
          <label className="sr-only" htmlFor="factoryscout-message">Write a message</label>
          <textarea id="factoryscout-message" rows={2} maxLength={3000} required value={draft}
            onChange={event => setDraft(event.target.value)} placeholder="Write a message to the other participant…" />
          <button type="submit" disabled={busy || !draft.trim()}>{busy ? "Sending…" : "Send message ↗"}</button>
        </form>
      </div>
    </div>}
  </section>;
}
